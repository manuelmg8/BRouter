export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/healthz") {
      return new Response("ok", {
        status: 200,
        headers: { "content-type": "text/plain; charset=utf-8" },
      });
    }

    return Response.json(
      {
        service: "pelotonic-worker",
        status: "running",
        message: "Worker route is configured. No upstream proxy is enabled.",
      },
      { status: 200 },
    );
  },
};
