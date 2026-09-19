#include <jni.h>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "common.h"
#include "sampling.h"
#include "llama.h"

namespace {
std::once_flag backend_once;

std::string generate_response(const std::string &model_path, const std::string &prompt) {
    std::call_once(backend_once, [] {
        llama_backend_init();
    });

    llama_model_params model_params = llama_model_default_params();
    llama_model *model = llama_model_load_from_file(model_path.c_str(), model_params);
    if (!model) {
        return "Unable to load the selected model on this phone.";
    }

    llama_context_params context_params = llama_context_default_params();
    context_params.n_ctx = 2048;
    context_params.n_batch = 256;
    context_params.n_threads = 4;
    context_params.n_threads_batch = 4;
    llama_context *context = llama_init_from_model(model, context_params);
    if (!context) {
        llama_model_free(model);
        return "Unable to prepare the selected model on this phone.";
    }

    const std::string formatted_prompt = "User: " + prompt + "\nAssistant:";
    const auto tokens = common_tokenize(context, formatted_prompt, true, true);
    if (tokens.empty()) {
        llama_free(context);
        llama_model_free(model);
        return "The prompt could not be tokenized.";
    }

    llama_batch batch = llama_batch_init(static_cast<int32_t>(tokens.size() + 1), 0, 1);
    for (size_t index = 0; index < tokens.size(); ++index) {
        batch.token[index] = tokens[index];
        batch.pos[index] = static_cast<llama_pos>(index);
        batch.n_seq_id[index] = 1;
        batch.seq_id[index][0] = 0;
        batch.logits[index] = false;
    }
    batch.logits[tokens.size() - 1] = true;

    if (llama_decode(context, batch) != 0) {
        llama_batch_free(batch);
        llama_free(context);
        llama_model_free(model);
        return "The model could not process the prompt.";
    }

    common_params_sampling sampling;
    sampling.temp = 0.7f;
    sampling.top_p = 0.9f;
    auto *sampler = common_sampler_init(model, sampling);
    const auto *vocab = llama_model_get_vocab(model);
    std::string response;
    constexpr int max_tokens = 256;

    for (int index = 0; index < max_tokens; ++index) {
        const llama_token token = common_sampler_sample(sampler, context, static_cast<int32_t>(tokens.size() - 1));
        common_sampler_accept(sampler, token, true);
        if (llama_vocab_is_eog(vocab, token)) break;

        char piece[256];
        const int piece_size = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, true);
        if (piece_size > 0) response.append(piece, piece_size);

        batch.token[0] = token;
        batch.pos[0] = static_cast<llama_pos>(tokens.size() + index);
        batch.n_seq_id[0] = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0] = true;
        batch.n_tokens = 1;
        if (llama_decode(context, batch) != 0) break;
    }

    common_sampler_free(sampler);
    llama_batch_free(batch);
    llama_free(context);
    llama_model_free(model);
    return response.empty() ? "The model returned an empty response." : response;
}
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_local_1llama_MainActivity_generateNative(
    JNIEnv *env,
    jobject,
    jstring model_path,
    jstring prompt) {
    const char *model_chars = env->GetStringUTFChars(model_path, nullptr);
    const char *prompt_chars = env->GetStringUTFChars(prompt, nullptr);
    const std::string result = generate_response(model_chars, prompt_chars);
    env->ReleaseStringUTFChars(model_path, model_chars);
    env->ReleaseStringUTFChars(prompt, prompt_chars);
    return env->NewStringUTF(result.c_str());
}
