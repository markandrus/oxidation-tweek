#include <stdint.h>
#include <stdio.h>

#include "src/rust.h"

int main() {
    char *result = set_bitrate_parameters("World", Tias);
    printf("%s\n", result);
    free(result);
}
