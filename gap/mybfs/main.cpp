#include <stdint.h>
#include <iostream>
#include <vector>

#ifdef __riscv
#include "sim_api.h"
#include "count_utils.h"
#endif // __riscv

void bfs(int N,
         uint32_t *edge_index,
         uint32_t *edge_size,
         uint32_t *edge_list,
         uint32_t *visited);
void bfs_vector(int N,
                uint32_t *edge_index,
                uint32_t *edge_size,
                uint32_t *edge_list,
                uint32_t *visited);

extern uint64_t global_id;

int main() {
  // 頂点数と辺数
  int N, M;
  std::cin >> N >> M;

  // グラフ入力受取 (ここでは無向グラフを想定)
  uint32_t edge_list[M];
  uint32_t edge_start[N];
  uint32_t edge_size[N];
  uint32_t visited[N];

  for (int i = 0; i < N; ++i) {
    edge_start[i] = 0;
    edge_size [i] = 0;
    visited   [i] = 0;
  }

  uint32_t last = -1;
  for (int i = 0; i < M; ++i) {
    int a, b;
    std::cin >> a >> b;
    // std::cerr << "a = " << a << ", b = " << b << '\n';
    if (last != a) {
      edge_start[a] = i;
    }
    edge_size[a]++;
    edge_list[i] = b;

    last = a;
  }

  global_id = 1;

  // 初期条件 (頂点 0 を初期ノードとする)
  visited[0] = global_id++;
  // for (int v = 0; v < N; ++v) std::cout << "edge_start " << v << ": " << edge_start[v] << '\n';
  // for (int v = 0; v < N; ++v) std::cout << "edge_size  " << v << ": " << edge_size[v] << '\n';
  bfs (N, edge_start, edge_size, edge_list, visited);

  // 結果出力 (各頂点の頂点 0 からの距離を見る)
  for (int v = 0; v < N; ++v) {
    if (visited[v]) {
      std::cout << v << ": " << visited[v] << ' ';
    }
  }
  std::cout << '\n';

#ifdef __riscv

  global_id = 1;
  // グラフ入力受取 (ここでは無向グラフを想定)
  uint32_t v_visited[N];
  for (int i = 0; i < N; ++i) {
    v_visited [i] = 0;
  }

  // 初期条件 (頂点 0 を初期ノードとする)
  v_visited[0] = global_id++;

  long long start_cycle = get_cycle();
  long long start_vecinst = get_vecinst();
  SimRoiStart();
  start_konatadump();
  bfs_vector (N, edge_start, edge_size, edge_list, v_visited);
  SimRoiEnd();
  stop_konatadump();
  long long end_cycle = get_cycle();
  long long end_vecinst = get_vecinst();
  printf("cycles = %lld\n", end_cycle - start_cycle);
  printf("vecinst = %lld\n", end_vecinst - start_vecinst);

  // 結果出力 (各頂点の頂点 0 からの距離を見る)
  for (int v = 0; v < N; ++v) {
    if (visited[v]) {
      std::cout << v << ": " << v_visited[v] << ' ';
    }
  }
  std::cout << '\n';

  bool match = true;
  for (int i = 0; i < N; i++) {
    if (visited[i] != v_visited[i]) {
      std::cout << "MISMATCH\n";
      match = false;
      break;
    }
  }
  if (match) {
    std::cout << "MATCH\n";
  }

#endif // __riscv
}
