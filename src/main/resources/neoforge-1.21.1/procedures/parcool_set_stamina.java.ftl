<#if input$ENTITY?? && input$VALUE??>
if (${input$ENTITY} instanceof net.minecraft.world.entity.player.Player _player) {
    try {
        final Object _attachment = com.alrex.parcool.common.attachment.Attachments.STAMINA.get();

        final java.lang.reflect.Method _getData = _player.getClass().getMethod(
            "getData",
            net.neoforged.neoforge.attachment.AttachmentType.class
        );
        final Object _current = _getData.invoke(_player, _attachment);

        final int _max = (int) _current.getClass().getMethod("max").invoke(_current);
        final int _target = (int) Math.max(0, Math.min(_max, Math.round(${input$VALUE})));

        final java.lang.reflect.Constructor<?> _ctor = _current.getClass()
            .getDeclaredConstructor(boolean.class, int.class, int.class);
        _ctor.setAccessible(true);

        final Object _new = _ctor.newInstance(false, _target, _max);

        final java.lang.reflect.Method _setData = _player.getClass().getMethod(
            "setData",
            net.neoforged.neoforge.attachment.AttachmentType.class,
            Object.class
        );
        _setData.invoke(_player, _attachment, _new);
    } catch (Throwable ignored) {
    }
}
</#if>