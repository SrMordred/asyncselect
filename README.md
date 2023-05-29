# Asyncselect

A Select for Futures, inspired by Rust `select!` macro. 

### Example:

```nim
var fut1 = async_func1();
var fut2 = async_func2();

# Will select the first returning async function
select:
    fut1 as result:
        echo result
    fut2 as result:
        echo result

```