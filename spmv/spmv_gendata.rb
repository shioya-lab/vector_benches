#!/usr/bin/env ruby

m = ARGV[0].to_i
n = ARGV[1].to_i
approx_nnz = ARGV[2].to_i

pnnz = approx_nnz.to_f/(m*n)
idx = Array[]
p = [0]

m.times {|i|
  n.times {|j|
    if rand() < pnnz then
      idx.push (j)
    end
  }
  p.push (idx.size)
}

nnz = idx.size
v = Array.new(n) { rand(1000) }
d = Array.new(nnz) { rand(1000) }

def printVec(t, name, data)
  printf("const %s %s[%d] = {", t, name, data.length)
  data.each_with_index {|d, index|
    print "  " + d.to_s
    puts "," if index != data.size-1
  }
  print("};\n\n")
end

def spmv(p, d, idx, v)
  y = Array.new
  for i in 0..(p.length-1) do
    yi = 0
    limit = 0
    if i == p.length-1 then
      limit = idx.size
    else
      limit = p[i+1]
    end
    for k in p[i]..(limit-1) do
      yi = yi + d[k]*v[idx[k]]
    end
    y[i] = yi
  end
  return y
end

printf("#define R %d\n", m)
printf("#define C %d\n", n)
printf("#define NNZ %d\n", nnz)
printVec("double", "val", d)
printVec("uint64_t", "idx", idx)
printVec("double", "x", v)
printVec("uint64_t", "ptr", p)
printVec("double", "verify_data", spmv(p, d, idx, v))
