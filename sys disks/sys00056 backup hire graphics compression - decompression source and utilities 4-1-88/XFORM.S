* Sound compression
* L.P.S. Nielsen 1988

* memopry to memopry art the mpment
Xformline
* Entry A0 -> start of block to transform
*       A1 -> where rtanformased data will go
* transforms N byte values where N is a power of two
* Note that the destination values are words not bytes
* Also N=/=8 is not really on now - need to reduce code for N<8
  CLR.L  D0
  CLR.L  D1
  CLR.L  D2
  CLR.L  D3
  CLR.L  D4
  CLR.L  D5
  CLR.L  D6
  CLR.L  D7

* read first 4 source values in
  MOVE.B (A0)+,D0
  MOVE.B (A0)+,D1
  MOVE.B (A0)+,D2
  MOVE.B (A0)+,D3
  MOVE.B D0,D4
  MOVE.B D1,D5
  MOVE.B D2,D6
  MOVE.B D3,D7
  
* Stage 1 of the tranform uses remaining 4 source values
  ADD.W  (A0),D0
  SUB.W  (A0)+,D4
  ADD.W  (A0),D1
  SUB.W  (A0)+,D5
  ADD.W  (A0),D2
  SUB.W  (A0)+,D6
  ADD.W  (A0),D3
  SUB.W  (A0)+,D7

* Stage 2 of the transform uses intermediate values from stage 1
  ADD.W  D0,D2    