<#include "mcitems.ftl">
<#if input$ITEM??>
{
	try {
		net.minecraft.world.item.ItemStack _stack = ${mappedMCItemToItemStackCode(input$ITEM, 1)};

		if (!_stack.isEmpty()) {
			boolean _hadEnchantments =
				_stack.has(net.minecraft.core.component.DataComponents.ENCHANTMENTS)
					|| _stack.has(net.minecraft.core.component.DataComponents.STORED_ENCHANTMENTS)
					|| _stack.has(net.minecraft.core.component.DataComponents.ENCHANTMENT_GLINT_OVERRIDE);

			_stack.remove(net.minecraft.core.component.DataComponents.ENCHANTMENTS);
			_stack.remove(net.minecraft.core.component.DataComponents.STORED_ENCHANTMENTS);
			_stack.remove(net.minecraft.core.component.DataComponents.ENCHANTMENT_GLINT_OVERRIDE);

			if (_hadEnchantments) {
				${package}.events.ParCoolApiBridgeEvents.fireItemEnchantmentsStripped(_stack);
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>