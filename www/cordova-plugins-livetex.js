module.exports =
{
    open: function (name, successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "Livetex",
            "open",
            [name]
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

    destroy: function (successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "Livetex",
            "destroy",
            []
        );
    },

    callback: function (successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            "Livetex",
            "callback",
            []
        );
    },
};