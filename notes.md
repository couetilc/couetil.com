# deno auth server

I need to generate a good salt

```deno
function getSalt(size: number): string {
  return [ ...crypto.getRandomValues(new Uint8Array(size)) ]
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}
```
