\ help
: help token find drop
         case ['] + of ." ( u1|n1 u2|n2 -- u3|n3 ) Addition " cr endof
              ['] - of ." ( u1|n1 u2|n2 -- u3|n3 ) Subtraction " cr endof
              ['] / of ." ( n1 n2 -- n3 ) n1 / n2 = n3 " cr endof
         words     
         endcase ;