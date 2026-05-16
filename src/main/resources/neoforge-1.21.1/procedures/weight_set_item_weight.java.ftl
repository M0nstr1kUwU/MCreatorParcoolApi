<#include "mcitems.ftl">
<#if input$ITEM?? && input$WEIGHT??>
{
	try {
		net.minecraft.world.item.ItemStack _stack = ${mappedMCItemToItemStackCode(input$ITEM, 1)};

		if (!_stack.isEmpty()) {
			${package}.weight.ParCoolApiWeightSystem.setItemWeight(_stack, (double) ${input$WEIGHT});
		}
	} catch (Throwable ignored) {
	}
}
</#if>