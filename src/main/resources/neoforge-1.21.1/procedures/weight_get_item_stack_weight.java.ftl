<#include "mcitems.ftl">
<#if input$ITEM??>
((java.util.function.Supplier<Double>) () -> {
	try {
		net.minecraft.world.item.ItemStack _stack = ${mappedMCItemToItemStackCode(input$ITEM, 1)};

		return !_stack.isEmpty()
			? ${package}.weight.ParCoolApiWeightSystem.getStackWeight(_stack)
			: 0.0D;
	} catch (Throwable ignored) {
		return 0.0D;
	}
}).get()
<#else>
0
</#if>