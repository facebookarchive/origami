(function(window)
{

var timerID = null;

$(document).ready(function()
{
    var openCallout = null;

    $(document).bind("touchend", function()
    {
        if (openCallout)
            openCallout.close();
    });

    $(".callout").each(function(anIndex, aCallout)
    {
        aCallout = $(aCallout);

        var owner = aCallout.parent();

        owner.mouseenter(function()
        {
            window.clearTimeout(timerID);

            var delay = parseInt(aCallout.attr("delay") || 0);

            timerID = window.setTimeout(function()
            {
                openCallout = aCallout;

                aCallout.show();

                if (!aCallout.children("canvas").length)
                    render(aCallout);

            }, delay);
        });

        if (aCallout.attr("delay"))
            aCallout.mouseenter(function()
            {
                aCallout.close();
            });

        owner.mouseleave(function()
        {
            window.clearTimeout(timerID);

            aCallout.close();
        });

        aCallout.close = function()
        {
            openCallout = null;
            aCallout.hide();
        }

        aCallout.parent().bind("touchend", function()
        {
            return false;
        });
    });
});

var MARGIN_TOP      = 24.0,
    MARGIN_BOTTOM   = 24.0,
    MARGIN_LEFT     = 7.0,
    MARGIN_RIGHT    = 7.0,
    TOP             = MARGIN_TOP + 0.5,
    LEFT            = MARGIN_LEFT + 0.5;
    BORDER_RADIUS   = 9.0,
    ANCHOR_HEIGHT   = 14.0,
    PI              = Math.PI;

function render(aCallout)
{
    var width = aCallout.outerWidth(),
        height = aCallout.outerHeight(),
        canvas = document.createElement("canvas");

    $(canvas).attr("width", width);
    $(canvas).attr("height", height);
    $(canvas).addClass("callout-render");

    aCallout.append(canvas);

    if (window["G_vmlCanvasManager"])
        G_vmlCanvasManager.initElement(canvas);

    width -= 10.0 * 2;
    height -= MARGIN_TOP + MARGIN_BOTTOM;

    var context = canvas.getContext("2d"),
        BORDER_RADIUS = 9.0,
        anchor = aCallout.attr("anchor");

    if (!anchor)
        anchor = width / 2 + 10.0;
    else
        anchor = parseFloat(anchor);

    var isBottomOriented = aCallout.attr("orientation") === "bottom";

    context.beginPath();
    context.arc(LEFT + BORDER_RADIUS, TOP + BORDER_RADIUS, BORDER_RADIUS, PI, 3 * PI / 2, false);

    if (isBottomOriented)
    {
        context.lineTo(anchor - 13.0, TOP);
        context.lineTo(anchor, TOP - ANCHOR_HEIGHT);
        context.lineTo(anchor + 13.0, TOP);
    }

    context.arc(LEFT + width - BORDER_RADIUS, TOP + BORDER_RADIUS, BORDER_RADIUS, 3 * PI / 2, 0,  false);
    context.arc(LEFT + width - BORDER_RADIUS, TOP + height - BORDER_RADIUS, BORDER_RADIUS, 0, PI / 2, false);

    if (!isBottomOriented)
    {
        context.lineTo(anchor + 13.0, TOP + height);
        context.lineTo(anchor, TOP + height + ANCHOR_HEIGHT);
        context.lineTo(anchor - 13.0, TOP + height);
    }

    context.arc(LEFT + BORDER_RADIUS, TOP + height - BORDER_RADIUS, BORDER_RADIUS, PI / 2, PI, false);

    context.closePath();

    context.shadowOffsetX = 0.0;
    context.shadowOffsetY = 4.0;
    context.shadowBlur = 11.0;
    context.shadowColor = "rgba(0, 0, 0, 0.25)";

    context.fillStyle = "white";
    context.strokeStyle = "rgba(0, 0, 0, 0.1)";
    context.fill();
    context.stroke();
}

})(window);
