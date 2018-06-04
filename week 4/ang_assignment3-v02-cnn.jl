# Convolutional neural network (thanks Mike Innes)

using Flux, Flux.Data.MNIST
using Flux: onehotbatch, argmax, crossentropy, throttle
using Base.Iterators: repeated, partition
# using CuArrays

# Classify MNIST digits with a convolutional network

imgs = MNIST.images()

labels = onehotbatch(MNIST.labels(), 0:9)

# Partition into batches of size 1,000
train = [(cat(4, float.(imgs[i])...), labels[:,i])
         for i in partition(1:60_000, 1000)]

train = gpu.(train)

# Prepare test set (first 1,000 images)
tX = cat(4, float.(MNIST.images(:test)[1:1000])...) |> gpu
tY = onehotbatch(MNIST.labels(:test)[1:1000], 0:9) |> gpu

m = Chain(
  Conv((2,2), 1=>16, relu),
  x -> maxpool(x, (2,2)),
  Conv((2,2), 16=>8, relu),
  x -> maxpool(x, (2,2)),
  x -> reshape(x, :, size(x, 4)),
  Dense(288, 10), softmax) |> gpu

m(train[1][1])

loss(x, y) = crossentropy(m(x), y)

accuracy(x, y) = mean(argmax(m(x)) .== argmax(y))

evalcb = throttle(() -> @show(accuracy(tX, tY)), 10)
opt = ADAM(params(m))

Flux.train!(loss, train, opt, cb = evalcb)
"""
accuracy(tX, tY) = 0.126
accuracy(tX, tY) = 0.126
accuracy(tX, tY) = 0.178
accuracy(tX, tY) = 0.281
accuracy(tX, tY) = 0.366
accuracy(tX, tY) = 0.533
accuracy(tX, tY) = 0.666
accuracy(tX, tY) = 0.693
"""
