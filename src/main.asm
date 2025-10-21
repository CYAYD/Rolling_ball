SECTION "Entry point", ROM0[$150]

main::
   
   call sc_game_init
   call sc_game_run

   di
   halt
