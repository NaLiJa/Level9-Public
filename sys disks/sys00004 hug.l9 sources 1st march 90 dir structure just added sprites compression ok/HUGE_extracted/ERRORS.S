;************************************************************************* 
;************************************************************************* 
;********  Error Codes Returned to Acode 
 
 
; Error codes returned in AX; AH is the error source, AL is the internal 
;  error number 
; 
;   AH	Error Source	AL  Error Code		Type	  	Action 
; 
;    0	Disc system	XX  Disc error codes	Advice   	None 
; 
;    1	Driver		00  Heap error		Warning/Fatal	Grab more 
;			01  No Transparencies	Warning		Grab more 
;			02  No MapLinks		Warning		Grab more	 
;			03  Cell out of range	Warning		Grab more	 
;			04  Purging Error	Warning/Fatal	Grab more	 
; 
;    2  Driver		XX  Requestor drawn	Advice		(1) 
; 
;    3  Disc system	XX  Sprites not found   Fatal		Restart! 
; 
; 
; (1)	If requestor has been drawn in the current window, then ignore as 
;	the screen will be updated; however if the requestor is outside 
;	the current window then the top window will have to be redrawn to 
;	erase the requestor 
; 
; 
 
 
