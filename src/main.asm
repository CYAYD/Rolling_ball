SECTION "Entry point", ROM0[$150]

main::
   
   ; Start at title screen, then go to game on A
   call sc_title_init
   call sc_title_run
   call sc_game_init
   call sc_game_run

   di
   halt
