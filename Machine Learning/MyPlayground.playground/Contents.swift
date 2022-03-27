import CoreML

var array:[UInt16]=[]
array+=[1,2,3,4]
let postureArray = array.map{NSNumber(value: $0)}
print(postureArray)


guard let postureMLArray = try? MLMultiArray(shape:[1,4], dataType:.double) else {
    fatalError("Unexpected runtime error. MLMultiArray")
}

// Copy the array into the MLMultiArray
for i in 0..<postureMLArray.count {
    postureMLArray[i] = postureArray[i]
    print(postureMLArray)
}
