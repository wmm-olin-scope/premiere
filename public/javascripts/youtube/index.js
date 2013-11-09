

var numStoriesToShow = 30;

function loadStories(done) {
    var url = "/story/youtube/popular?limit=" + numStoriesToShow;
    d3.json(url, function (err, result) {
        if (err) {
            console.log("Couldn't load popular: " + err);
        } else if (!result.success) {
            console.log("Couldn't load popular: " + result.error);
        } else {
            done(result.stories);
        }
    });
}

function Rect(topLeft, size) {
    this.topLeft = topLeft;
    this.size = size;
    this.recalculate();
}

Rect.prototype.recalculate = function () {
    this.bottomRight = add(this.topLeft, this.size);
    this.center = add(this.topLeft, scale(this.size, 0.5));

    this.left = this.topLeft[0];
    this.top = this.topLeft[1];
    this.right = this.bottomRight[0]
    this.bottom = this.bottomRight[1];
    this.width = this.size[0];
    this.height = this.size[1];
}

Rect.prototype.contains = function (point) {
    return this.left <= point[0] && point[0] <= this.right &&
           this.top <= point[1] && point[1] <= this.bottom;
}

Rect.prototype.overlapsX = function (other) {
    return rangesOverlap(this.left, this.right, 
                         other.left, other.right);
}

Rect.prototype.overlapsY = function (other) {
    return rangesOverlap(this.top, this.bottom, 
                         other.top, other.bottom);
}

Rect.prototype.intersects = function (other) {
    return this.overlapsX(other) && this.overlapsY(other);
}

function rectFromCenter(center, size) {
    return new Rect(add(center, scale(size, -0.5)), size);
}

function rangesOverlap(a1, b1, a2, b2) {
    return a1 <= b2 && b1 >= a2;
}

function add(p1, p2) {
    return [p1[0] + p2[0], p1[1] + p2[1]];
}

function scale(p, k) {
    return [p[0]*k, p[1]*k];
}

function copy(p) {
    return [p[0], p[1]];
}

var canvas = d3.select("svg#canvas");
var canvasRect = new Rect([0, 0], 
                          [canvas.attr("width"), canvas.attr("height")]);
var titleRect = rectFromCenter(canvasRect.center, [300, 50]);

var maxSize = [384, 216];
var numSteps = 50;
var stepSize = [maxSize[0]/numSteps, maxSize[1]/numSteps];
var minScale = 1/8;

function spawnRects(n, canvas) {
    var points = _.map(_.range(n), function () {
        var point;
        do {
            point = [_.random(canvasRect.left, canvasRect.right),
                     _.random(canvasRect.top, canvasRect.bottom)];
        } while (titleRect.contains(point));
        return  point;
    });

    //filter out points lying on top of eachother
    points = _.filter(points, function (point) {
        return !_.some(points, function (match) {
            return match !== point && 
                   match[0] == point[0] && match[1] == point[1];
        });
    });

    var rects = _.map(points, function (point) {
        return new Rect(point, [0, 0]);
    });
    rects.push(titleRect);
    var currentRects = rects.slice(0, rects.length-1);

    for (var step = 0; step < numSteps; step++) {
        if (!currentRects) break;

        for (var i = currentRects.length-1; i >= 0; i--) {
            var rect = currentRects[i];
            var overlapping = _.filter(rects, function (match) {
                if (match !== rect) {
                    return rangesOverlap(rect.left, rect.right, 
                                         match.left, match.right) ||
                           rangesOverlap(rect.top, rect.bottom,
                                         match.top, match.bottom);
                } else return false;
            });

            var hasExpanded = false;
            function isColliding() {
                return _.some(overlapping, function (other) {
                    return rect.intersects(other);
                });
            }

            // expand left, up
            var oldTopLeft = copy(rect.topLeft);
            var oldSize = copy(rect.size);
            rect.topLeft = add(rect.topLeft, scale(stepSize, -1));
            rect.size = add(rect.size, stepSize);
            rect.recalculate();
            if (rect.left < canvasRect.left || rect.top < canvasRect.top || 
                    isColliding()) {
                rect.topLeft = oldTopLeft;
                rect.size = oldSize;
                rect.recalculate();
            } else hasExpanded = true;

            // expand left, down
            oldTopLeft = copy(rect.topLeft);
            oldSize = copy(rect.size);
            rect.topLeft = add(rect.topLeft, [-stepSize[0], 0]);
            rect.size = add(rect.size, stepSize);
            rect.recalculate();
            if (rect.left < canvasRect.left || rect.bottom > canvasRect.bottom || 
                    isColliding()) {
                rect.topLeft = oldTopLeft;
                rect.size = oldSize;
                rect.recalculate();
            } else hasExpanded = true;

            // expand right, down
            oldSize = copy(rect.size);
            rect.size = add(rect.size, stepSize);
            rect.recalculate();
            if (rect.right > canvasRect.right || 
                    rect.bottom > canvasRect.bottom || isColliding()) {
                rect.topLeft = oldTopLeft;
                rect.size = oldSize;
                rect.recalculate();
            } else hasExpanded = true;

            // expand right, up
            oldTopLeft = copy(rect.topLeft);
            oldSize = copy(rect.size);
            rect.topLeft = add(rect.topLeft, [0, -stepSize[1]]);
            rect.size = add(rect.size, stepSize);
            rect.recalculate();
            if (rect.right > canvasRect.right || 
                    rect.top < canvasRect.top || isColliding()) {
                rect.topLeft = oldTopLeft;
                rect.size = oldSize;
                rect.recalculate();
            } else hasExpanded = true;

            if (!hasExpanded || (rect.size[0] >= maxSize[0])) {
                currentRects.splice(i, 1);
            }
        };
    }

    rects.pop(); // remove title rect
    return _.filter(rects, function (rect) {
        rect.topLeft = _.map(rect.topLeft, Math.round);
        rect.size = _.map(rect.size, Math.round);
        rect.recalculate();
        return rect.size[0] >= maxSize[0]*minScale;
    });
}

function debugRects(rects) {
    d3.select("#canvas").selectAll("rect")
      .data(rects.concat([titleRect])).enter().append("rect")
      .attr("transform", function(r) {
          return "translate(" + r.left + "," + r.top + ")";
      })
      .attr("width", function (r) { return r.width; })
      .attr("height", function (r) { return r.height; })
      .style("fill", function (r) {
          return r === titleRect ? "blue" : "red";
      });
}

$(function() {
    var rects = spawnRects(numStoriesToShow, canvas);
    console.log(rects);
    debugRects(rects);
});