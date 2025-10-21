INCLUDE "utils/constants.inc"
SECTION "Render System Code", ROM0

sys_render_init::
	
	ld hl, OAM_START
	ld b, OAM_SIZE
	xor a
	call memset_256

	ret

sys_render_update::
	
	call wait_vblank_start

	call man_entity_get_components

	ld de, OAM_START
	call memcpy_256

	ret