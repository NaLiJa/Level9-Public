/*
 *   Routine To Connect And Disconnect The Player Interupt server.
 *
 *   Copyright (c) 1987 By Level 9 Computing & Leon Thrane. All Rights Reserved.
 *   9 Mendip Road, Crown Wood, Bracknell, Berkshire RG12 3XG - (0344) 487597
 */

#include  "hero.h"
#include  <hardware/intbits.h>
#include  <exec/interrupts.h>

/*
 *   External Variables, Procedures, and Functions
 */

extern void    FreeMem(), AddIntServer(), RemIntServer(), InterruptServer(),
               PlayerPoll();
extern APTR    AllocMem();

struct    Interrupt *VertBIntr[2];

/*
 *   The routine to initialize my interupt server
 */

void InitializeInterrupt(strct)
struct InterruptStrct *strct;
   {
     if ((VertBIntr[0] = (struct Interrupt *) AllocMem(sizeof(struct Interrupt), MEMF_PUBLIC)) == NULL)
          bye_bye("Cannot create interrupt");
     if ((VertBIntr[1] = (struct Interrupt *) AllocMem(sizeof(struct Interrupt), MEMF_PUBLIC)) == NULL)
          bye_bye("Cannot create interrupt");

     VertBIntr[0]->is_Node.ln_Type = NT_INTERRUPT;
     VertBIntr[0]->is_Node.ln_Pri = 0;
     VertBIntr[0]->is_Node.ln_Name = "---* Atropos The Wanderer";
     VertBIntr[0]->is_Data = (APTR) strct;
     VertBIntr[0]->is_Code = InterruptServer;
     strct->SoftInt = (APTR) VertBIntr[1];

     VertBIntr[1]->is_Node.ln_Type = 0;
     VertBIntr[1]->is_Node.ln_Pri = 16;
     VertBIntr[1]->is_Node.ln_Name = "hey, what can I say...";
     VertBIntr[1]->is_Data = (APTR) strct;
     VertBIntr[1]->is_Code = PlayerPoll;

     AddIntServer(INTB_COPER, VertBIntr[0]);
   }

/*
 *   And a VERY small one to remove it again!
 */

void RemoveInterrupt()
   {
     RemIntServer(INTB_VERTB, VertBIntr[0]);
     FreeMem(VertBIntr[0], sizeof(struct Interrupt));
     FreeMem(VertBIntr[1], sizeof(struct Interrupt));
   }
