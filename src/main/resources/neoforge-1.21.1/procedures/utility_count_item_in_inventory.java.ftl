<#include "mcitems.ftl">
<#if input$ITEM?? && input$ENTITY??>
((java.util.function.Supplier<Double>) () -> {
	try {
		if (!(${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player)) {
			return 0.0D;
		}

		net.minecraft.world.item.ItemStack _target = ${mappedMCItemToItemStackCode(input$ITEM, 1)};

		if (_target.isEmpty()) {
			return 0.0D;
		}

		int _count = 0;

		for (int _slot = 0; _slot < _player.getInventory().getContainerSize(); _slot++) {
			net.minecraft.world.item.ItemStack _slotStack = _player.getInventory().getItem(_slot);

			if (!_slotStack.isEmpty() && _slotStack.is(_target.getItem())) {
				_count += _slotStack.getCount();
			}
		}

		return (double) _count;
	} catch (Throwable ignored) {
		return 0.0D;
	}
}).get()
<#else>
0
</#if>