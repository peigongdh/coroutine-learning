var q = nil

async function producer(d) {
    d = d + 1
    console.log("produce:" + d)
    await consumer(d)
}

async function consumer(d) {
    console.log("consume:"+d)
    await producer(d)
}

producer(0).catch(error => console.log(error.stack));

// function producer(d) {
//     d = d + 1
//     console.log("produce:" + d)
//     consumer(d)
// }

// function consumer(d) {
//     console.log("consume:"+d)
//     producer(d)
// }

// producer(0);