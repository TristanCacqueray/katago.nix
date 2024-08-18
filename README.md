# katago.nix

Generate KaTrain config using katago "human-like" model:

```ShellSession
$ nix build .#katrain.engine.human && cat result | jq
{
  "_enable_ownership": true,
  "altcommand": "",
  "config": "/nix/store/a2pq2q24n41404dzxjpy07a0a3pqan4y-katago-preaz_12k.cfg",
  "fastfrvisits": 30,
  "katago": "/nix/store/8j5zcs50917qm75gkf7z6h6kk35jcb28-katago-wrapper",
  "max_time": 0.8,
  "max_visits": 750,
  "model": "/nix/store/j3mzf0b4hqnjiia6lyk09p0ag13g9c3l-kata1-b28c512nbt-s7332806912-d4357057652.bin.gz",
  "threads": 12,
  "wide_root_noise": 0.04
}
```
