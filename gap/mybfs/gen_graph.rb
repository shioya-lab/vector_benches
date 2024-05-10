#!/bin/ruby
# coding: utf-8
require 'set'

graph_size = ARGV[0].to_i

# ペアを保存する配列
pair_set = Set.new

# 外側のループ: 各頂点に対して
for i in 0...graph_size
  # 内側のループの上限をランダムに設定
  # j_max = rand(graph_size / 10)
  # 一時的に上限を10に設定
  j_max = rand(10-1)+1

  # 内側のループ: ランダムなペアを生成
  for j in 0...j_max
    new_pair = [i, rand(graph_size)]
    redo if pair_set.include?(new_pair)  # すでに存在するペアの場合は再試行
    pair_set.add(new_pair)
  end
end

# グラフのサイズとペアリストのサイズを出力
puts "#{graph_size} #{pair_set.size}"

# ペアリストの内容を出力
pair_set.each do |p|
  puts "#{p[0]} #{p[1]}"
end
