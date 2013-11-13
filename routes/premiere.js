
var users = require('../data/users')
  , auth = require('../lib/auth')
  , utils = require('../lib/utils')
  , _ = require('underscore');


function getIndex(req, res) {
    res.render('premiere/index', {
        user: req.user
    });
}

function getPreshow(req, res) {
    var category = req.params.category;
    if (!_.contains(users.userCategories, category)) utils.fail(res, {
        message: "No such category: " + category
    })

    res.cookie("userCategory", category);
    res.render("premiere/preshow/" + category);
}

function getCategoryAsk(req, res) {
    res.render("premiere/category");
}

function getCountdown(req, res) {
    res.render("premiere/countdown");
}

function getMovie(req, res) {
    res.render("premiere/movie");
}

function getPostshow(req, res) {
    var category = req.params.category;
    if (!_.contains(users.userCategories, category)) utils.fail(res, {
        message: "No such category: " + category
    })
    res.render("premiere/postshow/" + category);
}

function getPartner(req, res) {
    res.render("premiere/partner");
}

exports.create = function(app) {
    app.get('/premiere', getIndex);
    app.get('/premiere/category', getCategoryAsk);
    app.get('/premiere/partner', getPartner)
    app.get('/premiere/preshow/:category', getPreshow);
    app.get('/premiere/countdown', getCountdown);
    app.get('/premiere/movie', getMovie);
    app.get('/premiere/postshow/:category', getPostshow);
};
