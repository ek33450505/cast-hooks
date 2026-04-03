class CastHooks < Formula
  desc "13 Claude Code hook scripts — observability, safety guards, and agent dispatch"
  homepage "https://github.com/ek33450505/cast-hooks"
  url "https://github.com/ek33450505/cast-hooks/archive/refs/heads/main.tar.gz"
  version "0.1.0"
  sha256 ""
  license "MIT"

  def install
    libexec.install Dir["scripts/*"]
    (libexec/"config").install Dir["config/*"]
    (libexec/"VERSION").write(File.read("VERSION"))
    prefix.install "VERSION"

    inreplace "bin/cast-hooks",
              'CAST_HOOKS_DIR=""',
              "CAST_HOOKS_DIR=\"#{libexec}\""

    inreplace "bin/cast-hooks",
              /CH_VERSION="\$\(cat.*\|\| echo .unknown.\)"/,
              "CH_VERSION=\"#{version}\""

    bin.install "bin/cast-hooks"
  end

  def caveats
    <<~EOS
      Install hooks to ~/.claude/scripts/ and merge settings:
        cast-hooks install

      Check which hooks are active:
        cast-hooks status

      List all available hooks:
        cast-hooks list
    EOS
  end

  test do
    system "#{bin}/cast-hooks", "--version"
  end
end
