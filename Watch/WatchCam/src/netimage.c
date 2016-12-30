#include "netimage.h"

NetImageContext* netimage_create_context(NetImageCallback callback, uint8_t *data) {
  NetImageContext *ctx = malloc(sizeof(NetImageContext));

  ctx->length = 0;
  ctx->index = 0;
  ctx->data = data;
  ctx->callback = callback;

  return ctx;
}

void netimage_destroy_context(NetImageContext *ctx) {
  free(ctx);
}

void netimage_initialize(NetImageCallback callback, uint8_t *data) {
  NetImageContext *ctx = netimage_create_context(callback, data);
  APP_LOG(APP_LOG_LEVEL_DEBUG, "NetImageContext = %p", ctx);
  app_message_set_context(ctx);
}

void netimage_deinitialize() {
  netimage_destroy_context(app_message_get_context());
  app_message_set_context(NULL);
}

void netimage_receive(DictionaryIterator *iter, void *context) {
  NetImageContext *ctx = (NetImageContext*) context;

  Tuple *tuple = dict_read_first(iter);
  if (!tuple) {
    APP_LOG(APP_LOG_LEVEL_ERROR, "Got a message with no first key! Size of message: %li", (uint32_t)iter->end - (uint32_t)iter->dictionary);
    return;
  }
  switch (tuple->key) {
    case NETIMAGE_DATA:
      APP_LOG(APP_LOG_LEVEL_DEBUG, "NETIMAGE_DATA");
      if (ctx->index + tuple->length <= ctx->length) {
        memcpy(ctx->data + ctx->index, tuple->value->data, tuple->length);

        ctx->index += tuple->length;
      }
      else {
        APP_LOG(APP_LOG_LEVEL_WARNING, "Not overriding rx buffer. Bufsize=%li BufIndex=%li DataLen=%i",
          ctx->length, ctx->index, tuple->length);
      }
      break;
    case NETIMAGE_BEGIN:
      APP_LOG(APP_LOG_LEVEL_DEBUG, "NETIMAGE_BEGIN");
      APP_LOG(APP_LOG_LEVEL_DEBUG, "Start transmission. Size=%lu", tuple->value->uint32);
      if (ctx->data != NULL) {
        ctx->length = tuple->value->uint32;
        ctx->index = 0;
      }
      else {
        APP_LOG(APP_LOG_LEVEL_WARNING, "Unable to allocate memory to receive image.");
        ctx->length = 0;
        ctx->index = 0;
      }
      break;
    case NETIMAGE_END:
      if (ctx->data && ctx->length > 0 && ctx->index > 0) {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "NETIMAGE_END");

        ctx->callback(context);

        if (ctx->data) {
          ctx->index = ctx->length = 0;
        }
        else {
          APP_LOG(APP_LOG_LEVEL_DEBUG, "Unable to create GBitmap. Is this a valid PBI?");
          ctx->index = ctx->length = 0;
        }
      }
      else {
        APP_LOG(APP_LOG_LEVEL_DEBUG, "Got End message but we have no image...");
      }
      break;
    default:
      // APP_LOG(APP_LOG_LEVEL_WARNING, "Unknown key in dict: %lu", tuple->key);
      break;
  }
}


