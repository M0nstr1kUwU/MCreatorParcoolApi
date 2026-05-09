<#include "mcitems.ftl">
<#if input$item??>
{
	try {
		net.minecraft.world.item.ItemStack _stack = ${mappedMCItemToItemStackCode(input$item, 1)};

		if (!_stack.isEmpty()) {
			boolean _hadEnchantments =
				_stack.has(net.minecraft.core.component.DataComponents.ENCHANTMENTS)
					|| _stack.has(net.minecraft.core.component.DataComponents.STORED_ENCHANTMENTS);

			_stack.remove(net.minecraft.core.component.DataComponents.ENCHANTMENTS);
			_stack.remove(net.minecraft.core.component.DataComponents.STORED_ENCHANTMENTS);

			if (_hadEnchantments) {
				${package}.events.ParCoolApiBridgeEvents.fireItemEnchantmentsStripped(_stack);
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>