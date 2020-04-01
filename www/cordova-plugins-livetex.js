module.exports =
{
    open: function (successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "Livetex",
            "open",
            []
        );
    },

    init: function (successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "Livetex",
            "init",
            []
        );
    },
};