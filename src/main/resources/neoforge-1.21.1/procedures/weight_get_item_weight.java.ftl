<#include "mcitems.ftl">
<#if input$item??>
((java.util.function.Supplier<Double>) () -> {
	try {
		net.minecraft.world.item.ItemStack __parcoolApiUnitWeightStack =
			${mappedMCItemToItemStackCode(input$item, 1)};

		return ${package}.weight.ParCoolApiWeightSystem.getUnitWeight(__parcoolApiUnitWeightStack);
	} catch (Throwable ignored) {
		return 0.0;
	}
}).get()
<#else>
0
</#if>