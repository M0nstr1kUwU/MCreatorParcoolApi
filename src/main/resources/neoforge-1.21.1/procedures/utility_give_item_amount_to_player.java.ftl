<#include "mcitems.ftl">
<#if input$ITEM?? && input$AMOUNT?? && input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		net.minecraft.world.item.ItemStack _templateStack = ${mappedMCItemToItemStackCode(input$ITEM, 1)};
		int _remaining = Math.max(0, ${opt.toInt(input$AMOUNT)});

		if (!_templateStack.isEmpty() && _remaining > 0) {
			int _maxStackSize = Math.max(1, _templateStack.getMaxStackSize());

			while (_remaining > 0) {
				int _count = Math.min(_remaining, _maxStackSize);
				_remaining -= _count;

				net.minecraft.world.item.ItemStack _stackToGive = _templateStack.copy();
				_stackToGive.setCount(_count);

				boolean _added = _player.getInventory().add(_stackToGive);

				if ((!_added || !_stackToGive.isEmpty()) && (("${field$DROP_OVERFLOW}").equals("TRUE"))) {
					_player.drop(_stackToGive, false);
				}
			}

			_player.getInventory().setChanged();
		}
	} catch (Throwable ignored) {
	}
}
</#if>