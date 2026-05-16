<#include "mcitems.ftl">
<#if input$ITEM?? && input$X?? && input$Y?? && input$Z?? && input$AMOUNT?? && input$DELAY??>
if (world instanceof net.minecraft.server.level.ServerLevel _level) {
	try {
		net.minecraft.world.item.ItemStack _templateStack = ${mappedMCItemToItemStackCode(input$ITEM, 1)};

		if (!_templateStack.isEmpty()) {
			int _amount = Math.max(1, ${opt.toInt(input$AMOUNT)});
			int _delay = Math.max(0, ${opt.toInt(input$DELAY)});
			int _maxStackSize = Math.max(1, _templateStack.getMaxStackSize());

			while (_amount > 0) {
				int _count = Math.min(_amount, _maxStackSize);
				_amount -= _count;

				net.minecraft.world.item.ItemStack _stackToSpawn = _templateStack.copy();
				_stackToSpawn.setCount(_count);

				net.minecraft.world.entity.item.ItemEntity _itemEntity = new net.minecraft.world.entity.item.ItemEntity(
					_level,
					${input$X},
					${input$Y},
					${input$Z},
					_stackToSpawn
				);

				_itemEntity.setPickUpDelay(_delay);

				<#if (field$DESPAWNABLE!"TRUE") == "FALSE">
				_itemEntity.setUnlimitedLifetime();
				</#if>

				_level.addFreshEntity(_itemEntity);
			}
		}
	} catch (Throwable ignored) {
	}
}
</#if>