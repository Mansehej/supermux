class Supermux < Formula
  desc "Directory-scoped tmux session manager with OpenTUI picker"
  homepage "https://github.com/Mansehej/supermux"
  head "https://github.com/Mansehej/supermux.git", branch: "main"

  depends_on "bun"
  depends_on "tmux"

  def install
    bin.install "bin/supermux"
    (share/"supermux").install "scripts/opentui-picker.ts"
    (share/"supermux").install "config/tmux.conf.snippet"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/supermux --help")
  end
end
