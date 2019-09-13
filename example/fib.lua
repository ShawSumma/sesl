
local function fun_if(n,t,f)
    if n() then
        return t()
    else
        return f()
    end
end

local function fib(n)
    return
        fun_if(
            function()
                return n<2
            end,
            function()
                return n
            end,
            function()
                return fib(n-2)+fib(n-1)
            end
        )
end

print(fib(30))