#include <stdint.h>
#include <stdio.h>

#include "src/rust.h"

int main() {
    char *result = greet("World");
    printf("%s\n", result);
    free(result);
}
