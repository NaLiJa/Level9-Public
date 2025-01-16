#######################################################
#                                                     #
# Standard implicit rules for inclusion in makefiles. #
# To include this file use the line:                  #
#                                                     #
# .INCLUDE :; MAKE.INC                                #
#                                                     #
#######################################################
#
# Suffix rules
#

.asm.bin :
      ASSEM.TTP $*.asm to $*.bin

.c.bin   :
      LC.TTP $*

.pas.bin :
      PASCAL.TTP $*.asm to $*.bin

#
# Prefix rules
#

asm\bin\ :
      ASSEM.TTP asm\$* to bin\$*

c\bin\   :
      LC1.TTP -otemp.q $<
      LC2.TTP -o$@ temp

pas\bin\ :
      PASCAL.TTP pas\$* to bin\$*

