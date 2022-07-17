# grabcraft2txt

Create step-by-step instructions from GrabCraft models.

## Requirements

- cURL
- grep
- sed
- jq
- Haskell:
    - Glasgow Haskell Compiler
    - aeson
    - unordered-containers
    - interpolate

## Usage Example

```shell
$ grabcraft2txt 'https://www.grabcraft.com/minecraft/spruce-medieval-house-1' output.txt
$ head output.txt
level 1
row 1
27 times:
    air
row 2
2 times:
    air
Chiseled Stone Bricks
Stone Brick Stairs (East)
air
```
