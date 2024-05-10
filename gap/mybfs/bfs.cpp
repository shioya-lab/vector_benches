#include <stdint.h>
#include <iostream>
#include <vector>
#include <queue>

uint64_t global_id = 1;

// #define DEBUG

void bfs(int N,
         uint32_t *edge_start,
         uint32_t *edge_size,
         uint32_t *edge_list,
         uint32_t *visited)
{
  std::vector<uint32_t> worklist;
  worklist.push_back(0);

  size_t worklist_front = 0;
  // BFS 開始 (キューが空になるまで探索を行う)
  while (worklist_front != worklist.size()) {
    int v = worklist[worklist_front]; // キューから先頭頂点を取り出す
    worklist_front++;
#ifdef DEBUG
    fprintf (stderr, "graph[%d] size = %d\n", v, edge_size[v]);
    std::cerr << "edge_start[" << v << "] = " << edge_start[v]
              << ", edge_size[" << v << "] = " << edge_size[v] << '\n';
#endif // DEBUG
    // v から辿れる頂点をすべて調べる
    for (int i = edge_start[v]; i < edge_start[v] + edge_size[v]; i++) {
      uint32_t nv = edge_list[i];
      if (visited[nv] == 0) {
        // 新たな白色頂点 nv について距離情報を更新してキューに追加する
        visited[nv] = global_id++;
#ifdef DEBUG
        std::cerr << "worklist push (" << nv << ")\n";
#endif // DEBUG
        worklist.push_back(nv);
      }
    }
  }
}

#ifdef __riscv

#include <riscv_vector.h>

void bfs_vector(int N,
                uint32_t *edge_start,
                uint32_t *edge_size,
                uint32_t *edge_list,
                uint32_t *visited)
{
  uint32_t *worklist = (uint32_t *)malloc(sizeof(uint32_t)*N);
  uint32_t *worklist_tail = worklist;
  uint32_t *worklist_head = worklist;
  *worklist_head = 0; worklist_head++;
  // std::vector<uint32_t> worklist;
  // worklist.push_back(0);

  while (worklist_tail != worklist_head) {

    size_t worklist_vl = __riscv_vsetvl_e32m1(worklist_head - worklist_tail);
    vuint32m1_t v_v = __riscv_vle32_v_u32m1(worklist_tail, worklist_vl);
    worklist_tail += worklist_vl;

    // Make offset with 32-bit
    vuint32m1_t v_voffset    = __riscv_vsll_vx_u32m1(v_v, 2, worklist_vl);
    vuint32m1_t v_edge_start = __riscv_vluxei32_v_u32m1(edge_start, v_voffset, worklist_vl);
    vuint32m1_t v_edge_size  = __riscv_vluxei32_v_u32m1(edge_size,  v_voffset, worklist_vl);

    for (int i = 0; i < worklist_vl; i++) {
      uint32_t s_edge_start = __riscv_vmv_x_s_u32m1_u32(v_edge_start);
      uint32_t s_edge_size  = __riscv_vmv_x_s_u32m1_u32(v_edge_size);

      uint32_t head_v_idx = __riscv_vmv_x_s_u32m1_u32(v_v);
#ifdef DEBUG
      fprintf (stderr, "edge_start[%d] = %d\n", head_v_idx, s_edge_start);
      fprintf (stderr, "edge_size [%d] = %d\n", head_v_idx, s_edge_size);
#endif // DEBUG
      for (int j = s_edge_start; j < s_edge_start + s_edge_size; ) {
        size_t vl = __riscv_vsetvl_e32m1 (s_edge_start + s_edge_size - j);
        vuint32m1_t v_edge_list     = __riscv_vle32_v_u32m1(&edge_list[j], vl);
        j += vl;
        vuint32m1_t v_nv_offset     = __riscv_vsll_vx_u32m1(v_edge_list, 2, vl);
        vuint32m1_t v_visited       = __riscv_vluxei32_v_u32m1(visited, v_nv_offset, vl);
        vbool32_t   v_visited_zero  = __riscv_vmseq_vx_u32m1_b32(v_visited, 0, vl);
        vuint32m1_t v_visited_add   = __riscv_vadd_vx_u32m1_m (v_visited_zero,
                                                               __riscv_viota_m_u32m1 (v_visited_zero, vl),
                                                               global_id, vl);
        uint64_t num_visited_zero = __riscv_vcpop_m_b32 (v_visited_zero, vl);
        global_id += num_visited_zero;
        __riscv_vsuxei32_v_u32m1_m (v_visited_zero, visited, v_nv_offset, v_visited_add, vl);

        vuint32m1_t v_aligned_visited_new = __riscv_vcompress_vm_u32m1(v_edge_list, v_visited_zero, vl);
        __riscv_vse32_v_u32m1(worklist_head, v_aligned_visited_new, num_visited_zero);
        worklist_head += num_visited_zero;

        //        for (int k = 0; k < vl; k++) {
        //          uint32_t new_visited = __riscv_vmv_x_s_u32m1_u32(v_visited);
        //          uint32_t new_nv      = __riscv_vmv_x_s_u32m1_u32(v_edge_list);
        //#ifdef DEBUG
        //          fprintf(stderr, "visited[%d](=%d), checking: %d\n", k, new_nv, new_visited);
        //#endif // DEBUG
        //          if (new_visited == 0) {
        //#ifdef DEBUG
        //            std::cerr << "worklist push (" << new_nv << ")\n";
        //#endif // DEBUG
        //            *(worklist_head++) = new_nv;
        //          }
        //          v_visited   = __riscv_vslide1down_vx_u32m1(v_visited,   0, vl);
        //          v_edge_list = __riscv_vslide1down_vx_u32m1(v_edge_list, 0, vl);
        //        }
      }

      worklist_vl = __riscv_vsetvl_e32m1 (worklist_vl);
      v_v = __riscv_vslide1down_vx_u32m1(v_v, 0, worklist_vl);
      v_edge_start = __riscv_vslide1down_vx_u32m1(v_edge_start, 0, worklist_vl);
      v_edge_size  = __riscv_vslide1down_vx_u32m1(v_edge_size,  0, worklist_vl);
    }
  }
}


#endif // __riscv
