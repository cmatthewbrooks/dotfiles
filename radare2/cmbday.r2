
# Draw attention to important stuff

ec call rgb:00ff45 . bold
ec jmp rgb:40c0f0
ec cjmp rgb:40c0f0
ec func_var_type rgb:40c0f0
ec bin rgb:40c0f0
ec num rgb:40c0f0
ec usrcmt rgb:40c0f0
ec comment rgb:40c0f0


# Basic text in white

ec help rgb:ffffff
ec input rgb:ffffff
ec prompt rgb:ffffff
ec label rgb:ffffff
ec args rgb:ffffff
ec fname rgb:ffffff
ec floc rgb:ffffff
ec fline rgb:ffffff
ec flag rgb:ffffff
ec func_var rgb:fffffff
ec func_var_addr rgb:ffffff
ec flow rgb:808080
ec flow2 rgb:808080
ec offset rgb:808080


# Ops, instrs, and regs in greyscale

ec b0x00 rgb:708090
ec b0x7f rgb:708090
ec b0xff rgb:708090
ec btext rgb:708090
ec invalid rgb:708090
ec other rgb:708090
ec math rgb:f0f0f0
ec mov rgb:f0f0f0
ec push rgb:f0f0f0
ec pop rgb:f0f0f0
ec cmp rgb:f0f0f0
ec ret rgb:f0f0f0
ec nop rgb:f0f0f0
ec reg rgb:f0f0f0
ec creg rgb:f0f0f0
ec crypto rgb:ffff00


# Still exploring this stuff

ec swi rgb:ffff00
ec trap rgb:ffff00
ec widget_bg rgb:303030
ec widget_sel rgb:ff0000
ec ai.write rgb:40c0f0
ec ai.exec rgb:40c0f0
ec ai.read rgb:f0c0c0
ec ai.seq rgb:f000f0
ec ai.ascii rgb:f0f0f0
ec graph.box rgb:708090
ec graph.box2 rgb:d04010
ec graph.box3 rgb:a0f020
ec graph.box4 rgb:a0f020
ec graph.true rgb:40f020
ec graph.false rgb:d04010
ec graph.current rgb:a0f020
ec graph.traced rgb:009000
ec graph.trufae rgb:004080
ec gui.cflow rgb:ffff00
ec gui.dataoffset rgb:ffff00
ec gui.background rgb:000000
ec gui.alt_background rgb:ffffff
ec gui.border rgb:000000
ec wordhl rgb:ff0000
ec linehl rgb:000040
