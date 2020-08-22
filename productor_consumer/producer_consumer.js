var i = 0

async function producer() {
    while (true) {
        if (i >= 5) {
            break
        }
        i ++
        console.log("produce:" + i)
        await consumer()
    }
}

async function consumer() {
    while (true) {
        if (i >= 5) {
            break
        }
        console.log("consume:" + i)
        await producer()
    }
}

producer().catch(error => console.log(error.stack));