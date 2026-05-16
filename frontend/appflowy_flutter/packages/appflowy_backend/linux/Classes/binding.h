#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>


int64_t init_sdk(char *path);

void async_command(int64_t port, const uint8_t *input, uintptr_t len);

const uint8_t *sync_command(const uint8_t *input, uintptr_t len);

int32_t set_stream_port(int64_t port);

void link_me_please(void);

void rust_log(int64_t level, const char *data);

void set_env(const char *data);
