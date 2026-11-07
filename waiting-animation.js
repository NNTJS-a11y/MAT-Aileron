/* Static membrane, moving illumination. No logo, vertex or layout transforms. */
function createAileronWaitingAnimation(canvas, container, apiButton) {
    const context = canvas.getContext('2d');
    const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
    let source = null, faces = [], active = false, frame = null, epoch = 0, lastPaint = -100;
    let width = 96, height = 54;
    function rebuild() {
        const rect = canvas.getBoundingClientRect();
        width = rect.width || 96; height = rect.height || 54;
        const ratio = Math.min(window.devicePixelRatio || 1, 2);
        canvas.width = Math.round(width * ratio); canvas.height = Math.round(height * ratio);
        if (!context || !source || !Array.isArray(source.vertices) || !Array.isArray(source.faces)) return;
        context.setTransform(ratio, 0, 0, ratio, 0, 0);
        const vertices = source.vertices;
        const projected = vertices.map(v => [(v[0] - v[1]) * .9, -(v[0] + v[1]) * .38 - v[2] * 1.35]);
        const used = [];
        source.faces.forEach(face => face.forEach(index => used.push(projected[index - 1])));
        if (!used.length) return;
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
        used.forEach(p => { minX = Math.min(minX, p[0]); maxX = Math.max(maxX, p[0]); minY = Math.min(minY, p[1]); maxY = Math.max(maxY, p[1]); });
        const scale = Math.min((width - 10) / (maxX - minX), (height - 8) / (maxY - minY));
        const points = projected.map(p => [(p[0] - (minX + maxX) / 2) * scale + width / 2, (p[1] - (minY + maxY) / 2) * scale + height / 2]);
        faces = source.faces.map(indices => {
            const world = indices.map(index => vertices[index - 1]);
            const z = world.reduce((sum, p) => sum + p[2], 0) / 4;
            const depth = world.reduce((sum, p) => sum + p[0] + p[1], 0) / 4;
            const u = world[1].map((v, i) => v - world[0][i]);
            const v = world[3].map((value, i) => value - world[0][i]);
            const normal = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]];
            const norm = Math.hypot(normal[0], normal[1], normal[2]) || 1;
            const shade = .63 + .31 * Math.abs(normal[2] / norm);
            const low = [37, 113, 178], high = [235, 125, 62];
            const t = Math.max(0, Math.min(1, z));
            const color = low.map((value, i) => (value + (high[i] - value) * t) * shade);
            return { points: indices.map(index => points[index - 1]), depth: depth, color: color };
        }).sort((a, b) => b.depth - a.depth);
    }
    function paint(time) {
        if (!context) return;
        context.clearRect(0, 0, width, height);
        const phase = motion.matches ? .4 : Math.max(0, time - epoch) % 3600 / 3600;
        const eased = phase * phase * (3 - 2 * phase);
        const lightDepth = 1.85 - 3.7 * eased; // Far edge to the near edge.
        const fade = Math.pow(Math.sin(Math.PI * phase), .65);
        faces.forEach(face => {
            const distance = (face.depth - lightDepth) / .52;
            const gleam = Math.exp(-distance * distance) * fade * .48;
            const color = face.color.map(value => Math.round(value + (255 - value) * gleam));
            context.beginPath();
            face.points.forEach((point, index) => index ? context.lineTo(point[0], point[1]) : context.moveTo(point[0], point[1]));
            context.closePath(); context.fillStyle = 'rgb(' + color.join(',') + ')'; context.fill();
        });
    }
    function cancel() { if (frame !== null) cancelAnimationFrame(frame); frame = null; }
    function tick(time) {
        frame = null;
        if (!active || document.hidden || motion.matches) return;
        if (time - lastPaint >= 32) { paint(time); lastPaint = time; }
        frame = requestAnimationFrame(tick);
    }
    function start() {
        cancel(); epoch = performance.now(); lastPaint = -100;
        paint(epoch);
        if (context && !motion.matches && !document.hidden) frame = requestAnimationFrame(tick);
    }
    function update(data) {
        if (data && data.surface && !source) { source = data.surface; rebuild(); }
        const next = !!(data && data.generating);
        container.classList.toggle('active', next);
        container.setAttribute('aria-hidden', next ? 'false' : 'true');
        apiButton.disabled = next;
        if (next !== active) { active = next; if (active) start(); else { cancel(); if (context) context.clearRect(0,0,width,height); } }
    }
    window.addEventListener('resize', function () { rebuild(); if (active) paint(performance.now()); });
    document.addEventListener('visibilitychange', function () { if (active && !document.hidden) start(); else cancel(); });
    const motionChanged = function () { if (active) start(); };
    if (motion.addEventListener) motion.addEventListener('change', motionChanged); else if (motion.addListener) motion.addListener(motionChanged);
    return { update: update, isActive: function () { return active; } };
}
