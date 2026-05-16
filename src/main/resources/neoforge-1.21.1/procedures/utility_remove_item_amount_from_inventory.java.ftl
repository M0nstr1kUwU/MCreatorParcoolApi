<#include "mcitems.ftl">
<#if input$ITEM?? && input$AMOUNT?? && input$ENTITY??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
	try {
		net.minecraft.world.item.ItemStack _target = ${mappedMCItemToItemStackCode(input$ITEM, 1)};
		int _remaining = Math.max(0, ${opt.toInt(input$AMOUNT)});

		if (!_target.isEmpty() && _remaining > 0) {
			for (int _slot = 0; _slot < _player.getInventory().getContainerSize() && _remaining > 0; _slot++) {
				net.minecraft.world.item.ItemStack _slotStack = _player.getInventory().getItem(_slot);

				if (!_slotStack.isEmpty() && _slotStack.is(_target.getItem())) {
					int _removed = Math.min(_remaining, _slotStack.getCount());
					_slotStack.shrink(_removed);
					_remaining -= _removed;

					if (_slotStack.isEmpty()) {
						_player.getInventory().setItem(_slot, net.minecraft.world.item.ItemStack.EMPTY);
					}
				}
			}

			_player.getInventory().setChanged();
		}
	} catch (Throwable ignored) {
	}
}
</#if>