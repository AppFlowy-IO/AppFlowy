#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

int64_t init_logger();

int64_t init_sdk(char *path);

int32_t init_stream(int64_t port);

void async_command(int64_t port, const uint8_t *input, uintptr_t len);

void async_query(int64_t port, const uint8_t *input, uintptr_t len);

const uint8_t *sync_command(const uint8_t *input, uintptr_t len);

void free_rust(
    uint8_t *ptr,
    uint32_t length);

void link_me_please(void);