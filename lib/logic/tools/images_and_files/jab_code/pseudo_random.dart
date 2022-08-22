const UINT32_MAX = 4294967295;
int lcg64_seed = 42;

int temper(int x) {
  x ^= x>>11;
  x ^= x<<7 & 0x9D2C5680;
  x ^= x<<15 & 0xEFC60000;
  x ^= x>>18;
  return x;
}

int lcg64_temper() {
  lcg64_seed = 6364136223846793005 * lcg64_seed + 1; //6364136223846793005ULL
  return temper(lcg64_seed >> 32);
}

void setSeed(int seed) {
  lcg64_seed = seed;
}
