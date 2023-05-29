import unittest
import std/asyncdispatch

import asyncselect

test "Basic Usage":

    proc sleep_test( msecs: int ): Future[int] {.async.} = 
        await sleepAsync(msecs)
        return msecs

    let fut1 = sleep_test(100)
    let fut2 = sleep_test(200)
    let fut3 = sleep_test(300)

    select:
        fut1 as r1:
            check r1 == 100
        fut2 as r2:
            check false # should not be here
        fut3 as r3:
            check false # should not be here

    
