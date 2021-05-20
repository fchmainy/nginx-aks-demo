$(document).ready(function () {
    $("#plus-adjective-icon").click(function () {
        $("#adjective-popup").show();
    });
    //Contact Form validation on click event
    $("#adjective-form").on("submit", function () {
        var valid = true;
        $(".info").html("");
        $("inputBox").removeClass("input-error");

        var adjective = $("#adjective").val();

        if (adjective == "") {
            $("#adjective-info").html("required.");
            $("#adjective").addClass("input-error");
        }
        return valid;

    });
});

$(document).ready(function () {
    $("#plus-animal-icon").click(function () {
        $("#animal-popup").show();
    });
    //Contact Form validation on click event
    $("#animal-form").on("submit", function () {
        var valid = true;
        $(".info").html("");
        $("inputBox").removeClass("input-error");

        var animal = $("#animal").val();

        if (animal == "") {
            $("#animal-info").html("required.");
            $("#animal").addClass("input-error");
        }
        return valid;

    });
});

$(document).ready(function () {
    $("#plus-color-icon").click(function () {
        $("#color-popup").show();
    });
    //Contact Form validation on click event
    $("#color-form").on("submit", function () {
        var valid = true;
        $(".info").html("");
        $("inputBox").removeClass("input-error");

        var color = $("#color").val();

        if (color == "") {
            $("#color-info").html("required.");
            $("#color").addClass("input-error");
        }
        return valid;

    });
});

$(document).ready(function () {
    $("#plus-location-icon").click(function () {
        $("#location-popup").show();
    });
    //Contact Form validation on click event
    $("#location-form").on("submit", function () {
        var valid = true;
        $(".info").html("");
        $("inputBox").removeClass("input-error");

        var location = $("#location").val();

        if (location == "") {
            $("#location-info").html("required.");
            $("#location").addClass("input-error");
        }
        return valid;

    });
});
