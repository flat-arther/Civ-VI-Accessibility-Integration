using CivVIAccessInstaller.Core;

namespace CivVIAccessInstaller.UI;

internal sealed class ProgressForm : Form
{
    private readonly Label _status;
    private readonly ProgressBar _bar;
    private readonly Button _cancel;
    private readonly CancellationTokenSource _cancellation = new();

    private ProgressForm(string title)
    {
        Text = "Civilization VI Accessibility Installer";
        AccessibleName = title;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        ControlBox = false;
        ClientSize = new Size(520, 150);
        Font = SystemFonts.MessageBoxFont;

        var heading = new Label
        {
            Text = title,
            Font = new Font(Font, FontStyle.Bold),
            Location = new Point(12, 12),
            Size = new Size(496, 24),
        };

        _status = new Label
        {
            Text = "Starting...",
            Location = new Point(12, 45),
            Size = new Size(496, 30),
        };

        _bar = new ProgressBar
        {
            Location = new Point(12, 80),
            Size = new Size(496, 22),
            Minimum = 0,
            Maximum = 1000,
        };

        _cancel = new Button
        {
            Text = "Cancel",
            Location = new Point(428, 112),
            Size = new Size(80, 28),
        };
        _cancel.Click += (_, _) =>
        {
            _cancel.Enabled = false;
            _status.Text = "Cancelling...";
            _cancellation.Cancel();
        };

        Controls.AddRange(new Control[] { heading, _status, _bar, _cancel });
        CancelButton = _cancel;
    }

    public static (bool Cancelled, Exception? Error) Run(
        IWin32Window owner,
        string title,
        Func<IProgress<Installer.ProgressInfo>, CancellationToken, Task> work)
    {
        using var form = new ProgressForm(title);
        Exception? error = null;

        var progress = new Progress<Installer.ProgressInfo>(value =>
        {
            form._status.Text = value.Status;
            form._status.AccessibleName = value.Status;
            form._bar.Value = Math.Clamp(value.Percentage, 0, 1000);
        });

        form.Shown += (_, _) =>
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await work(progress, form._cancellation.Token).ConfigureAwait(false);
                }
                catch (OperationCanceledException)
                {
                    // Reported through Cancelled.
                }
                catch (Exception ex)
                {
                    error = ex;
                }
                finally
                {
                    if (form.IsHandleCreated) form.BeginInvoke(form.Close);
                }
            });
        };

        form.ShowDialog(owner);
        return (form._cancellation.IsCancellationRequested, error);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) _cancellation.Dispose();
        base.Dispose(disposing);
    }
}
