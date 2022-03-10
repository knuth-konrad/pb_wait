# Wait

_Wait a specified amount of seconds or (optionally) until certain keys are pressed._

---

## Usage

`Wait /time=<number of seconds> [/key=<key to skip>] [/minimum=<minimum wait time although key was pressed>]`

E.g. `Wait /t=10 /k=x`, waits for 10 seconds or until 'x' is pressed. Upper/lower case doesn't matter. In addition to 'x', &lt;SPACE&gt; and &lt;ESC&gt; are also recognized as valid keys.

## Parameters

- /t or /time  
Number of seconds to wait.

- /k or /key  
Key to skip the pause.

- /m or /minimum  
Wait at least &lt;minimum&gt; number of seconds, although a key is pressed. `/k` needs to be passed for `/m` to have any effect.

Please note: if no key is specified, the program can still be terminated by CTRL+BREAK.
